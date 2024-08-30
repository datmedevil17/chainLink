
const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");



module.exports = buildModule("Upload", (m) => {


  const Upload = m.contract("Upload", []);

  return { Upload };
});



