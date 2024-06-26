async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());
    const ETHCoinTrading = await ethers.getContractFactory("ETHCoinTrading");

    const ethCoinTrading = await ETHCoinTrading.deploy();
    console.log("RentableNFT address:", ethCoinTrading.address);

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });