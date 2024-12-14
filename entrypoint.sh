#!/bin/sh
set -e
set -o pipefail

# ENVIRONMENT VARIABLES:
# [OPTIONAL]: TARGET_REPOSITORY, PROJECT_DIR, BUILD_DIR, BUILD_BRANCH, GITHUB_HOSTNAME
# [MANDATORY]: TOKEN

# When does these optional env variables become mandatory?
# TARGET_REPOSITORY: If you wish to deploy the BUILD_BRANCH to a different remote repository
# PROJECT_DIR: If your project directory is not the repository's base directory
# BUILD_DIR: If the static build is generated in a different directory and not in ${PROJECT_DIR}/build directory
# BUILD_BRANCH: If you want to publish the build to different branch and not to 'build' branch
# GITHUB_HOSTNAME: If the hostname of github, is not 'github.com'

# NOTE:
# This action assumes that your project has a build script available in package.json which generates the static build using the necessary package.
# BUILD_DIR is relative to PROJECT_DIR
# You can use this action with other frameworks/libraries by just adding a 'build' script to package.json and passing the static build-directory path through BUILD_DIR env variable.



# SCRIPT:
# Checks if the value of TARGET_REPOSITORY is empty
# Checks for GITHUB_REPOSITORY, if it's empty
# Exits with status code 1, if both of them are empty
if [[ -z "$TARGET_REPOSITORY" ]]; then
    if [[ -z "$GITHUB_REPOSITORY" ]]; then
        echo "Set the GITHUB_REPOSITORY env variable."
        exit 1
    fi
    TARGET_REPOSITORY=${GITHUB_REPOSITORY}
fi

# TOKEN is the GitHub Personal Access Token to access and push the build code to the target repository's new/existing branch.
# Checks for token and exits with an error code, if it's empty.
if [[ -z "$TOKEN" ]]; then
    echo "Set the TOKEN env variable which can access the $TARGET_REPOSITORY"
    exit 1
fi

# PROJECT_DIR is the directory is the base dir from where dir references are taken and where the package.json is found.
# Assumes it as . by default
if [[ -z "$PROJECT_DIR" ]]; then
    PROJECT_DIR="."
fi

# BUILD_DIR is the directory to where the static build will be output (relative to PROJECT_DIR) on executing the command yarn build.
# Assumes it as ./build by default
if [[ -z "$BUILD_DIR" ]]; then
    BUILD_DIR="build"
fi

# BUILD_BRANCH is the branch where the build is deployed.
# Takes it as 'build' by default
if [[ -z "$BUILD_BRANCH" ]]; then
    BUILD_BRANCH="build"
fi

# If empty, sets the value of GITHUB_HOSTNAME variable as github.com i.e. default value
if [[ -z "$GITHUB_HOSTNAME" ]]; then
    GITHUB_HOSTNAME="github.com"
fi

main() {
    echo "Starting build..."

    # remote_repo="https://${TOKEN}@${GITHUB_HOSTNAME}/${TARGET_REPOSITORY}.git"
    remote_repo="https://x-access-token:${TOKEN}@${GITHUB_HOSTNAME}/${TARGET_REPOSITORY}.git"
    # remote_branch=$BUILD_BRANCH

    echo "Using yarn $(yarn --version)"

    cd $PROJECT_DIR

    echo "Install yarn dependencies"
    yarn install --frozen-lockfile --silent

    echo "Building in $(pwd) directory"
    yarn build

    cd $BUILD_DIR
    git init
    git config --local user.email "action@github.com"
    git config --local user.name "GitHub Action"
    git add -f .
    git commit -m "Deploy the static build to ${BUILD_BRANCH} branch of ${TARGET_REPOSITORY}"
    git push --force ${remote_repo} master:${BUILD_BRANCH}
}

main "$@"
