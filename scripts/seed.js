const hre = require("hardhat")

const tokens = (n) => {
    return ethers.parseUnits(n.toString(), 18)
}

function wait(seconds) {
    const milliseconds = seconds * 1000
    return new Promise(resolve => setTimeout(resolve, milliseconds))
}

async function main() {
    const DAPP_ADDRESS ="0x5FbDB2315678afecb367f032d93F642f64180aa3"
    const mUSDC_ADDRESS = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"
    const mLINK_ADDRESS = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
    const EXCHANGE_ADDRESS = "0xcf7ed3acca5a467e9e704c703e8d87f634fb0fc9"
    const FLASH_LOAN_USER_ADDRESS = "0x663f3ad617193148711d28f5334ee4ed07016602"

    const dapp = await hre.ethers.getContractAt("Token", DAPP_ADDRESS)
    console.log(`Token fetched: ${await dapp.getAddress()}`)

    const mUSDC = await hre.ethers.getContractAt("Token", mUSDC_ADDRESS)
    console.log(`Token fetched: ${await mUSDC.getAddress()}`)

    const mLINK = await hre.ethers.getContractAt("Token", mLINK_ADDRESS)
    console.log(`Token fetched: ${await mLINK.getAddress()}`)

    const exchange = await hre.ethers.getContractAt("Exchange", EXCHANGE_ADDRESS)
    console.log(`Exchange fetched: ${await exchange.getAddress()}\n`)

    const flashLoanUser = await hre.ethers.getContractAt("FlashLoanUser", FLASH_LOAN_USER_ADDRESS)
    console.log(`FlashLoanUser fetched: ${await flashLoanUser.getAddress()}\n`)

    // Fetch accounts from wallet - these are unlocked
    const accounts = await ethers.getSigners()

    // This is the main account who deploys
    const deployer = accounts[0]

    // This is who collects fees from the exchange
    const collector = accounts[1]

    // These will represent a regular users account
    const user1 = accounts[2]
    const user2 = accounts[3]

    //
    // Let's Distribute tokens to the users
    //

    const AMOUNT = 10000
    let transaction

    // Deployer transfers 100,000 Dapp...
    transaction = await dapp.connect(deployer).transfer(user1.address, tokens(AMOUNT))
    await transaction.wait()
    console.log(`Transferred${AMOUNT} tokens from ${deployer.address} to ${user1.address}\n`)

    // Deployer transfers 100,00 mUSDC
    transaction = await mUSDC.connect(deployer).transfer(user1.address, tokens(AMOUNT))
    await transaction.wait()
    console.log(`Transferred${AMOUNT} tokens from ${deployer.address} to ${user1.address}\n`)

    //
    // Users deposit their tokens into the exchange
    //

    // User 1 approves 100,000 Dapp...
    transaction = await dapp.connect(user1).approve(await exchange.getAddress(), tokens(AMOUNT))
    await transaction.wait()
    console.log(`Approved ${AMOUNT} DAPP from ${user1.address}`)

    // User 1 deposits 100,000 Dapp...
    transaction = await exchange.connect(user1).depositToken(DAPP_ADDRESS, tokens(AMOUNT))
    await transaction.wait()
    console.log(`Deposited ${AMOUNT} DAPP from ${user1.address}\n`)

    // User 2 approves 100,000 mUSDC...
    transaction = await mUSDC.connect(user2).approve(await exchange.getAddress(), tokens(AMOUNT))
    await transaction.wait()
    console.log(`Approved ${AMOUNT} mUSDC from ${user2.address}`)

    // User 2 deposits 100,000 mUSDC...
    transaction = await exchange.connect(user2).depositToken(mUSDC_ADDRESS, tokens(AMOUNT))
    await transaction.wait()
    console.log(`Deposited ${AMOUNT} mUSDC from ${user2.address}\n`)

    //
    // Seed a cancelled order
    //

    // User 1 makes order to get tokens
    let orderId
    transaction = await exchange.connect(user1).makeOrder(mUSDC_ADDRESS, tokens(1), DAPP_ADDRESS, tokens(1))
    result = await transaction.wait()
    console.log(`Made order from ${user1.address}`)

    orderId = result.logs[0].args.id

    // User 1 cancels order
    transaction = await exchange.connect(user1).cancelOrder(orderId)
    result = await transaction.wait()
    console.log(`Cancelled order from ${user1.address}\n`)

    // wait 1 second
    await wait(1)

    // Fill some orders
    for(var i = 1; i <= 3; i++) {
        transaction = await exchange.connect(user1).makeOrder(mUSDC_ADDRESS, tokens(10), DAPP_ADDRESS, tokens(10 * i))
        result = await transaction.wait()
        console.log(`Made order from ${user1.address}`)

        // User 2 fills order
        orderId = result.logs[0].args.id
        transaction = await exchange.connect(user2).fillOrder(orderId)
        result = await transaction.wait()
        console.log(`Filled order from ${user2.address}`)

        // Wait 1 second
        await wait(1)
    }

    //
    // Seed some open orders
    //

    // User 1 makes 5 orders
    // User 12 wants to sell DAPPP for mUSDC
    for (let i = 1; 1 <=5.; i++) {
        transaction = await exchange.connect(user1).makeOrder(mUSDC_ADDRESS, tokens(10 *i), DAPP_ADDRESS, tokens(10 *i))
        result = await transaction.wait()

        console.log(`Made order from ${user1.address}`)

        // Wait 1 second
        await wait(1)
    }

    // User 2 makes 5 orders
    // UIser 2 wants to buy DAPP for mUSDC
    for (let i = 1; 1 <=5.; i++) {
        transaction = await exchange.connect(user2).makeOrder(DAPP_ADDRESS, tokens(10 *i), mUSDC_ADDRESS, tokens(10 *i))
        result = await transaction.wait()

        console.log(`Made order from ${user2.address}`)

        // Wait 1 second
        await wait(1)
    }

    //
    // Perform some flash loans
    //

    for (let i = 0; i < 3; i++) {
        transaction = await flashLoanUser.connect(user1).getFlashLoan(DAPP_ADDRESS, tokens(1000))
        result = await transaction.wait()

        console.log(`Flash loan executed from ${user1.address}`)

        // Wait 1 second
        await wait(1)
    }

}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
