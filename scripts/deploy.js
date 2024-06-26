async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());
    const stakingcoin = await ethers.getContractFactory("Coin");

    const StakingCoin = await stakingcoin.deploy("VHCoin", "VH");
    console.log("RentableNFT address:", StakingCoin.address);

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });