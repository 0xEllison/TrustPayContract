// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  
    const TrustPay = await hre.ethers.getContractFactory("TrustPay");
    const trustPay = await TrustPay.deploy("0xbeEf4e5ad55d19526E7f99c56E59C9355E59e328");
    console.log("TrustPay deployed to:", trustPay.address);
}
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });