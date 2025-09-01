#!/bin/bash
# CSFrace Scrape - Submodule Update Script
# Safely updates git submodules with validation

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Update specific submodule
update_submodule() {
    local submodule_path=$1
    local submodule_name=$(basename "$submodule_path")
    
    if [ ! -d "$submodule_path" ]; then
        log_warning "Submodule $submodule_name not found at $submodule_path"
        return 1
    fi
    
    log_info "Updating $submodule_name..."
    
    cd "$submodule_path"
    
    # Get current and remote commits
    local current_commit=$(git rev-parse HEAD)
    git fetch origin
    local remote_commit=$(git rev-parse origin/main 2>/dev/null || git rev-parse origin/master)
    
    if [ "$current_commit" = "$remote_commit" ]; then
        log_info "$submodule_name is already up to date"
        cd ..
        return 0
    fi
    
    # Show what's changing
    log_info "Changes in $submodule_name:"
    git log --oneline "$current_commit..$remote_commit" | head -5
    
    # Update to latest
    git merge "$remote_commit"
    
    cd ..
    log_success "$submodule_name updated successfully"
    return 0
}

# Main update function
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                 Submodule Update Utility                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Ensure we're in git repository root
    if [ ! -d ".git" ]; then
        log_error "Must be run from git repository root"
        exit 1
    fi
    
    # Initialize submodules if needed
    if [ ! -f ".gitmodules" ]; then
        log_warning "No .gitmodules file found"
        log_info "This is normal for a new wrapper repository"
        exit 0
    fi
    
    git submodule update --init --recursive
    
    local updates_made=false
    
    # Update each submodule
    if update_submodule "backend"; then
        updates_made=true
    fi
    
    if update_submodule "frontend"; then
        updates_made=true
    fi
    
    # Commit updates if any
    if [ "$updates_made" = "true" ]; then
        log_info "Committing submodule updates..."
        
        git add .
        git commit -m "chore(submodules): update to latest versions

$(cd backend && echo "Backend: $(git log -1 --format='%h %s')")
$(cd frontend && echo "Frontend: $(git log -1 --format='%h %s')")"
        
        log_success "Submodule updates committed"
        
        # Ask about pushing
        read -p "Push changes to remote? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git push origin HEAD
            log_success "Changes pushed to remote"
        fi
    else
        log_info "No submodule updates available"
    fi
}

# Handle script options
case "${1:-update}" in
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo "Commands:"
        echo "  update    Update all submodules (default)"
        echo "  backend   Update backend submodule only"
        echo "  frontend  Update frontend submodule only"
        echo "  status    Show submodule status"
        echo "  help      Show this help"
        ;;
    "backend")
        update_submodule "backend"
        ;;
    "frontend")
        update_submodule "frontend"
        ;;
    "status")
        log_info "Submodule status:"
        git submodule status
        ;;
    "update"|*)
        main
        ;;
esac