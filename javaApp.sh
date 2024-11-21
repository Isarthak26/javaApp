bash
#!/bin/bash

# Variables
REPO_URL="https://your-repo-url.git"   # Replace with your repository URL
REPO_DIR="/path/to/your/repo"           # Local directory to clone the repo
BRANCH_NAME=${1:-"main"}                # Default to 'main' branch if not provided
BUILD_TOOL="mvn"                        # Change to your build tool (e.g., mvn, gradle)
ARTIFACTS_DIR="/path/to/artifacts"     # Directory to publish artifacts
TIMEOUT_DURATION=60                      # Timeout duration in seconds

# Clone the repository if it doesn't exist
if [ ! -d "$REPO_DIR" ]; then
    echo "Cloning the repository..."
    git clone -b "$BRANCH_NAME" "$REPO_URL" "$REPO_DIR"
else
    echo "Repository already exists. Pulling the latest changes..."
    cd "$REPO_DIR" || exit
    git checkout "$BRANCH_NAME"
    git pull origin "$BRANCH_NAME"
fi

# Function to check for code changes
check_for_changes() {
    cd "$REPO_DIR" || exit
    git fetch origin "$BRANCH_NAME"
    if [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/$BRANCH_NAME)" ]; then
        return 0 # Changes are available
    else
        return 1 # No changes
    fi
}

# Main execution
echo "Starting build process for branch: $BRANCH_NAME"
start_time=$(date +%s)

# Check for changes and build if changes are detected
while true; do
    if check_for_changes; then
        echo "Code changes detected. Starting build..."
        
        echo "Building the application..."
        cd "$REPO_DIR" || exit
        $BUILD_TOOL clean package -DskipTests
        if [ $? -ne 0 ]; then
            echo "Build failed!"
            exit 1
        fi

        echo "Publishing artifacts..."
        cp "$REPO_DIR/target/*.jar" "$ARTIFACTS_DIR"  # Adjust as necessary
        echo "Artifacts published to $ARTIFACTS_DIR"
        
        echo "Build and publishing completed successfully."
        break
    fi
    
    # Check if we exceeded the timeout duration
    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))
    
    if [ "$elapsed_time" -ge "$TIMEOUT_DURATION" ]; then
        echo "Build process timed out after $TIMEOUT_DURATION seconds."
        exit 1
    fi
    
    echo "No changes detected. Polling again in 5 seconds..."
    sleep 5
done
