

set -e  

echo "🚀 Starting deployment process..."

# Load all possible Node.js paths and environments
export PATH=$HOME/.local/bin:$HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:$PATH

# Source all possible profile files
[ -f ~/.bashrc ] && source ~/.bashrc
[ -f ~/.bash_profile ] && source ~/.bash_profile  
[ -f ~/.profile ] && source ~/.profile

# Load NVM if it exists
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

# If NVM is loaded, use the default node version
if command -v nvm >/dev/null 2>&1; then
    nvm use default 2>/dev/null || nvm use node 2>/dev/null || true
fi

# Verify Node.js and npm are available
echo "📋 Checking Node.js installation..."
if ! command -v node >/dev/null 2>&1; then
    echo "❌ ERROR: Node.js not found in PATH"
    echo "Current PATH: $PATH"
    exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
    echo "❌ ERROR: npm not found in PATH" 
    echo "Current PATH: $PATH"
    exit 1
fi

echo "✅ Node.js version: $(node --version)"
echo "✅ npm version: $(npm --version)"

# Navigate to project directory
echo "📁 Navigating to project directory..."
cd cicd || { 
    echo "❌ ERROR: cicd directory not found"; 
    echo "Available directories: $(ls -la)";
    exit 1; 
}
echo "✅ Current directory: $(pwd)"

# Pull latest changes
echo "🔄 Pulling latest changes from git..."
git pull origin main
echo "✅ Git pull completed"

# Install dependencies
echo "📦 Installing npm dependencies..."
if npm ci --only=production 2>/dev/null; then
    echo "✅ Dependencies installed with npm ci"
else
    echo "⚠️  npm ci failed, falling back to npm install"
    npm install
    echo "✅ Dependencies installed with npm install"
fi

# Build the project
echo "🔨 Building the project..."
npm run build
echo "✅ Build completed"

# Stop existing processes
echo "🛑 Stopping existing processes..."
pkill -f "npm.*start" 2>/dev/null || true
pkill -f "node.*next" 2>/dev/null || true
sleep 2
echo "✅ Existing processes stopped"

# Start the application in background
echo "🎬 Starting the application..."
nohup npm run start > ~/cicd/app.log 2>&1 &

# Wait and verify the process started
echo "⏳ Waiting for application to start..."
sleep 5

if pgrep -f "npm.*start" >/dev/null || pgrep -f "node.*next" >/dev/null; then
    echo "✅ Application started successfully!"
    echo "✅ Process ID: $(pgrep -f "npm.*start" 2>/dev/null || pgrep -f "node.*next" 2>/dev/null)"
    echo "📄 Log file: ~/cicd/app.log"
else
    echo "⚠️  WARNING: Could not verify if application started"
    echo "📄 Last 10 lines of application log:"
    tail -n 10 ~/cicd/app.log 2>/dev/null || echo "No log file found"
    exit 1
fi

echo "🎉 Deployment completed successfully!"
echo "🌐 Your Next.js application should now be running"