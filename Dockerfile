FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy project files
COPY . .

# Compile contracts
RUN npx hardhat compile

# Expose Hardhat node port
EXPOSE 8545

# Start Hardhat node and deploy contracts
CMD ["npx", "hardhat", "node"]
