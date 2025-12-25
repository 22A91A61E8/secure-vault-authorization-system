const hre = require("hardhat");

async function main() {
  console.log("Deploying contracts...");

  // Deploy AuthorizationManager
  const AuthorizationManager = await hre.ethers.getContractFactory("AuthorizationManager");
  const authManager = await AuthorizationManager.deploy();
  await authManager.waitForDeployment();
  console.log("AuthorizationManager deployed to:", await authManager.getAddress());

  // Deploy SecureVault
  const SecureVault = await hre.ethers.getContractFactory("SecureVault");
  const vault = await SecureVault.deploy(await authManager.getAddress());
  await vault.waitForDeployment();
  console.log("SecureVault deployed to:", await vault.getAddress());

  console.log("Deployment complete!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
