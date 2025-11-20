const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("UserModule", (m) => {
    // Remember #0 is the deployer and #1 is the fee account
    const USER = m.getAccount(2)

    // The exchange contract must already be deployed
    const EXCHANGE_ADDRESS = "0xcf7ed3acca5a467e9e704c703e8d87f634fb0fc9"

    const flashLoanUser = m.contract(
        "FlashLoanUser",
        [EXCHANGE_ADDRESS],
        { from: USER }
    )

    return { flashLoanUser }
});
