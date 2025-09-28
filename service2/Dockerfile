FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --only=production

# Copy application code
COPY app.js .

# Create vStorage directory
RUN mkdir -p /app

# Expose port
EXPOSE 3000

# Run the application
CMD ["npm", "start"]
