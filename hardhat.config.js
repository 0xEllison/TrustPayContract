require("@nomicfoundation/hardhat-toolbox");

const private_key_1 = "c7244175a1075add8e5269ca33a7128ca5e5d966e7951b42b72b5afedd8edc97";
const private_key_2 = "f47e3b1e633ab0a3c42654f97e17fb6b205d142b94b57b78ca9a945ec9206e0c";
const private_key_3 = "0f23759f17d52aaa915aee886d2a7376a8518e6f17bc7c6ca9b421ce021e591a";
const private_key_4 = "08b04105f1bc549f41ce2566b7d0b7ff37c5d6c58cb14c5ee8e8f2853d7f6cd1";

const ALCHEMY_API_KEY = "XEcdSPziHKVpLQvUSD5IXCQJjWgkcGqg";
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.9",
  networks:{
    ganache:{
      url:`http://127.0.0.1:7545`,
      accounts:[`0x${private_key_1}`,`0x${private_key_2}`,`0x${private_key_3}`,`0x${private_key_4}`]
    }
  }
};
