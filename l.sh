#!/bin/bash

# GitHub API URL
GITHUB_API_URL="https://api.github.com"

# Function to get the GitHub token
get_github_token() {
    read -s -p "Enter your GitHub Personal Access Token: " token
    echo $token
}

# Function to get the GitHub headers
get_headers() {
    local token=$1
    echo -e "Authorization: token $token\nAccept: application/vnd.github.v3+json"
}

# Function to initialize a repository
init_repo() {
    local token=$1
    local username=$2
    local repo_name=$3
    url="$GITHUB_API_URL/user/repos"
    payload="{\"name\": \"$repo_name\", \"private\": false}"
    response=$(curl -s -X POST $url -H "$(get_headers $token)" -d "$payload")
    if [[ $(echo $response | jq -r '.message') == "Created" ]]; then
        echo "Repository '$repo_name' created successfully."
    else
        echo "Failed to create repository: $response"
    fi
}

# Function to add a file to the repository
add_file() {
    local token=$1
    local username=$2
    local repo_name=$3
    local file_path=$4
    local github_api_url="https://api.github.com"

    # Check if the file exists
    if [[ ! -f $file_path ]]; then
        echo "File '$file_path' does not exist."
        return 1
    fi

    # Encode file content to base64
    local content
    content=$(base64 -w 0 "$file_path")
    local filename
    filename=$(basename "$file_path")
    local url="$github_api_url/repos/$username/$repo_name/contents/$filename"
    local payload
    payload=$(jq -nc --arg msg "Add $filename" --arg content "$content" '{message: $msg, content: $content}')

    # Send the request
    local response
    response=$(curl -s -X PUT "$url" \
        -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        -d "$payload")

    # Check the response
    if [[ $(echo "$response" | jq -r '.content.name') == "$filename" ]]; then
        echo "File '$filename' added to repository '$repo_name'."
    else
        echo "Failed to add file: $response"
    fi
}

# Example usage:
# add_file "your_github_token" "your_username" "your_repo" "path/to/your/file"


# Function to view commit logs
log() {
    local token=$1
    local username=$2
    local repo_name=$3
    url="$GITHUB_API_URL/repos/$username/$repo_name/commits"
    response=$(curl -s $url -H "$(get_headers $token)")
    echo $response | jq -r '.[] | "Commit ID: \(.sha)\nMessage: \(.commit.message)\nTimestamp: \(.commit.author.date)\n----------------------------------------"'
}

# Function to check repository status (list files)
status() {
    local token=$1
    local username=$2
    local repo_name=$3
    url="$GITHUB_API_URL/repos/$username/$repo_name/contents"
    response=$(curl -s $url -H "$(get_headers $token)")
    echo $response | jq -r '.[] | " - \(.name)"'
}

# Menu system
menu() {
    token=$(get_github_token)
    read -p "Enter your GitHub username: " username
    while true; do
        echo -e "\nGitHub Version Control System (GVCS)"
        echo "1. Initialize Repository"
        echo "2. Add File to Repository"
        echo "3. Commit Changes"
        echo "4. View Commit Logs"
        echo "5. Check Repository Status"
        echo "6. Exit"
        read -p "Select an option: " choice

        case $choice in
            1)
                read -p "Enter repository name: " repo_name
                init_repo $token $username $repo_name
                ;;
            2)
                read -p "Enter repository name: " repo_name
                read -p "Enter file path to add: " file_path
                add_file $token $username $repo_name $file_path
                ;;
            3)
                read -p "Enter repository name: " repo_name
                read -p "Enter commit message: " message
                # Committing changes is handled during file addition in GitHub API
                echo "Commit message: '$message'"
                ;;
            4)
                read -p "Enter repository name: " repo_name
                log $token $username $repo_name
                ;;
            5)
                read -p "Enter repository name: " repo_name
                status $token $username $repo_name
                ;;
            6)
                echo "Exiting GVCS. Goodbye!"
                break
                ;;
            *)
                echo "Invalid option. Please try again."
                ;;
        esac
    done
}

menu