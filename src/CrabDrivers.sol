// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract CrabDrivers {
    mapping(address => bytes32) public driverToData;
    mapping(uint256 => address[]) public districtToDrivers;
    mapping(address => bytes32) public driverToActiveOrders;
    mapping(address => bytes32[]) public driverToPastOrders;

    function register(
        address _driver,
        bytes32 _data,
        uint256 _secret,
        uint256 _district
    ) external {
        string memory _message = "driver data";
        bytes32 dataHashed = keccak256(
            abi.encodePacked(_data, _message, _secret)
        );
        driverToData[_driver] = dataHashed;
        districtToDrivers[_district].push(_driver);
    }

    function getEthSignedMessageHash(bytes32 _hashMessage)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _hashMessage
                )
            );
    }

    function signIn(
        address _driver,
        uint256 _identifier,
        string calldata _name,
        uint256 _secret,
        address _to,
        bytes calldata _signature
    ) external view returns (bool result) {
        bytes32 messageHash = driverToData[_driver];
        bytes32 ethSignedMesssageHash = getEthSignedMessageHash(messageHash);

        result = recover(ethSignedMesssageHash, _signature) == _driver;
    }

    function recover(bytes32 _ethSignedMessage, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessage, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function checkRegistered(address _driver)
        external
        view
        returns (bool result)
    {
        bytes32 driverData = driverToData[_driver];
        result = driverData != 0;
    }

    function getDriverActiveOrders(address _driver)
        external
        view
        returns (bytes32 order)
    {
        order = driverToActiveOrders[_driver];
    }

    function getDriverPastOrders(address _driver)
        external
        view
        returns (bytes32[] memory orders)
    {
        orders = driverToPastOrders[_driver];
    }

    function addActiveOrder(address _driver, bytes32 _orderId) external {
        driverToActiveOrders[_driver] = _orderId;
    }

    function removeActiveOrder(address _driver, bytes32 _orderId) external {
        delete driverToActiveOrders[_driver];
        driverToPastOrders[_driver].push(_orderId);
    }
}
