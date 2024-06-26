async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());
    const StakeNFT = await ethers.getContractFactory("StakeNFT");

    const stakeNFT = await StakeNFT.deploy("0x0D5844D6cb1d4AAd1505c7eB459a69A23291415F");


    console.log("RentableNFT address:", stakeNFT.address);




}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });