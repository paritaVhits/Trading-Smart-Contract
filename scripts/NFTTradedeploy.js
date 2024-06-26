async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());
    const TradingNFT = await ethers.getContractFactory("NFTTrading");

    const tradingNFT = await TradingNFT.deploy();


    console.log("RentableNFT address:", tradingNFT.address);




}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });