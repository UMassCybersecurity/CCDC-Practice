#!/bin/bash
# Package a challenge under challenges/<name>/ for distribution (zip it up,
# hand it to Google Drive, etc). See CLAUDE.md's "Packaging" section for the
# full rationale. Run with no args for usage.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$REPO_ROOT/dist"

usage() {
    cat <<'EOF'
Usage: scripts/package-challenge.sh <challenge-dir-name> [options]

Options:
  --bundle candidate|instructor|both   Which bundle(s) to produce (default: both)
  --offline                            Docker challenges only: docker save the
                                        built image(s) into the candidate bundle
                                        instead of a 'build:' step, so the
                                        candidate doesn't need registry access.
  --build-box                          Windows/AD and Linux-VM challenges only:
                                        vagrant up + vagrant package the challenge
                                        into a pre-provisioned .box for the
                                        candidate bundle. SLOW (VM boot + package).
                                        Run once per challenge before its candidate
                                        bundle can be built.

Output lands in dist/ at the repo root (gitignored).

Examples:
  scripts/package-challenge.sh 09-webshell-hunt --offline
  scripts/package-challenge.sh 02-noisy-web
  scripts/package-challenge.sh 01-find-persistence --build-box
  scripts/package-challenge.sh 01-find-persistence --bundle candidate
EOF
}

if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
    exit 0
fi

NAME=$1; shift
BUNDLE=both
OFFLINE=0
BUILD_BOX=0
while [ $# -gt 0 ]; do
    case "$1" in
        --bundle) BUNDLE=$2; shift 2 ;;
        --offline) OFFLINE=1; shift ;;
        --build-box) BUILD_BOX=1; shift ;;
        *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
done

SRC="$REPO_ROOT/challenges/$NAME"
[ -d "$SRC" ] || { echo "ERROR: challenges/$NAME does not exist" >&2; exit 1; }

detect_family() {
    if [ -f "$SRC/Vagrantfile" ] && grep -q 'shared/base' "$SRC/Vagrantfile"; then
        echo windows
    elif [ -f "$SRC/Vagrantfile" ] && grep -q 'ansible_local' "$SRC/Vagrantfile"; then
        echo linux-vm
    elif [ -f "$SRC/docker-compose.yml" ]; then
        echo docker
    else
        echo "ERROR: cannot detect challenge family for $NAME (no Vagrantfile or docker-compose.yml)" >&2
        exit 1
    fi
}
FAMILY=$(detect_family)
mkdir -p "$DIST"

echo "==> $NAME  (family: $FAMILY, bundle: $BUNDLE${OFFLINE:+, offline:$OFFLINE})"

# --- instructor bundle: the whole directory, answer key and all -----------
package_instructor() {
    local stage; stage=$(mktemp -d)
    rsync -a --exclude '.vagrant' "$SRC"/ "$stage"/
    rm -f "$DIST/${NAME}-instructor.zip"
    (cd "$stage" && zip -rq "$DIST/${NAME}-instructor.zip" .)
    rm -rf "$stage"
    echo "    wrote dist/${NAME}-instructor.zip"
}

# --- candidate bundle: no ANSWER.md, no score_me, no provisioning script --
package_candidate_docker() {
    local stage; stage=$(mktemp -d)
    rsync -a --exclude '.vagrant' --exclude 'ANSWER.md' --exclude 'scripts/score_me.*' \
        "$SRC"/ "$stage"/

    if [ "$OFFLINE" = 1 ]; then
        echo "    building images for offline bundle..."
        (cd "$SRC" && docker compose build -q)
        # Resolve each service's image explicitly rather than trying to zip
        # `--services` against `--images`/`--images <svc>` — neither is
        # reliable: the bulk lists aren't guaranteed to share row order
        # (confirmed non-deterministic between calls), and filtering
        # `--images` to one service still pulls in that service's
        # dependencies' images too (confirmed: `--images app` also returned
        # redis's image, since app depends_on redis). Instead: services with
        # an explicit `image:` get it straight from the resolved JSON config;
        # build-only services get Compose's documented default tag,
        # `<project>-<service>` (project = directory basename), which the
        # build step above just confirmed by tagging it that way.
        local services project config_json
        services=$(cd "$SRC" && docker compose config --services)
        project=$(basename "$SRC")
        config_json=$(cd "$SRC" && docker compose config --format json)
        mkdir -p "$stage/images"
        echo "$services" | while read -r svc; do
            [ -z "$svc" ] && continue
            local img
            img=$(echo "$config_json" | jq -r --arg s "$svc" '.services[$s].image // empty')
            img=${img:-${project}-${svc}}
            echo "    docker save $img"
            docker save "$img" -o "$stage/images/${svc}.tar"
            # Only services with a local 'build:' step need rewriting to
            # 'image:' — pulled images (e.g. redis:7-alpine) stay as-is.
            if grep -qE "^  ${svc}:" "$stage/docker-compose.yml" && \
               awk -v s="  ${svc}:" 'BEGIN{f=0} $0==s{f=1;next} /^  [a-zA-Z]/{f=0} f && /^    build:/{found=1} END{exit !found}' "$stage/docker-compose.yml"; then
                awk -v s="  ${svc}:" -v img="$img" '
                    BEGIN{f=0}
                    $0==s{f=1; print; next}
                    /^  [a-zA-Z]/{f=0}
                    f && /^    build:/{print "    image: " img; next}
                    {print}
                ' "$stage/docker-compose.yml" > "$stage/docker-compose.yml.new"
                mv "$stage/docker-compose.yml.new" "$stage/docker-compose.yml"
            fi
        done
        cat > "$stage/LOAD-OFFLINE-IMAGES.md" <<EOF
# Loading offline images

Before \`docker compose up\`, load the pre-built images this bundle shipped with:

\`\`\`
for f in images/*.tar; do docker load -i "\$f"; done
\`\`\`
EOF
        echo "    rewrote docker-compose.yml to use baked images"
    fi

    rm -f "$DIST/${NAME}-candidate.zip"
    (cd "$stage" && zip -rq "$DIST/${NAME}-candidate.zip" .)
    rm -rf "$stage"
    echo "    wrote dist/${NAME}-candidate.zip"
}

package_candidate_linux_vm() {
    # The ansible_local playbook (scripts/break_server.yml) IS the answer key
    # for this family too — it's what plants the vulnerabilities at
    # 'vagrant up' — so the same pre-baked-box requirement as Windows applies.
    local box="$DIST/${NAME}-provisioned.box"
    if [ "$BUILD_BOX" = 1 ]; then
        echo "    building provisioned box (boots the VM + runs ansible)..."
        (cd "$SRC" && vagrant up)
        (cd "$SRC" && vagrant package --output "$box")
        (cd "$SRC" && vagrant destroy -f)
        echo "    wrote $box"
    fi
    if [ ! -f "$box" ]; then
        echo "    ERROR: no provisioned box at $box — scripts/break_server.yml" >&2
        echo "    IS the answer key (see CLAUDE.md), so a candidate bundle can't ship it." >&2
        echo "    Re-run with --build-box first." >&2
        return 1
    fi

    # Pull this challenge's own hostname/memory/cpus out of its Vagrantfile
    # so the minimal candidate Vagrantfile matches (defaults if not found).
    local hostname mem cpus
    hostname=$(grep -oP 'config\.vm\.hostname\s*=\s*"\K[^"]+' "$SRC/Vagrantfile" || true)
    hostname=${hostname:-$NAME}
    mem=$(grep -oP 'vb\.memory\s*=\s*"?\K[0-9]+' "$SRC/Vagrantfile" | head -1 || true)
    mem=${mem:-1024}
    cpus=$(grep -oP 'vb\.cpus\s*=\s*\K[0-9]+' "$SRC/Vagrantfile" | head -1 || true)
    cpus=${cpus:-1}

    local stage; stage=$(mktemp -d)
    cat > "$stage/Vagrantfile" <<EOF
require 'rbconfig'
is_apple_silicon = RbConfig::CONFIG['host_os'] =~ /darwin/ && RbConfig::CONFIG['host_cpu'] =~ /arm|aarch64/
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'vmware_desktop' if is_apple_silicon
Vagrant.configure("2") do |config|
  config.vm.box = "ccdc/${NAME}-candidate"
  config.vm.hostname = "${hostname}"
  config.vm.network "private_network", ip: "192.168.56.10"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "${mem}"
    vb.cpus = ${cpus}
  end
  config.vm.provider "vmware_desktop" do |vmware|
    vmware.vmx["memsize"] = "${mem}"
    vmware.vmx["numvcpus"] = "${cpus}"
    vmware.allowlist_verified = true
  end
end
EOF
    cp "$SRC/README.md" "$stage/README.md"
    cat > "$stage/SETUP.md" <<EOF
# Setup

This candidate bundle ships without a provisioning script — the box is
already provisioned. Alongside this zip you should have received
\`${NAME}-provisioned.box\` (a separate, large file).

1. \`vagrant box add ccdc/${NAME}-candidate /path/to/${NAME}-provisioned.box\`
2. \`vagrant up\`
3. Follow README.md's Connect section.
EOF
    rm -f "$DIST/${NAME}-candidate.zip"
    (cd "$stage" && zip -rq "$DIST/${NAME}-candidate.zip" .)
    rm -rf "$stage"
    echo "    wrote dist/${NAME}-candidate.zip (small — ships alongside $box, not inside it)"
}

package_candidate_windows() {
    local box="$DIST/${NAME}-provisioned.box"
    if [ "$BUILD_BOX" = 1 ]; then
        echo "    building provisioned box (this boots a full VM, can take 15-30+ min)..."
        (cd "$SRC" && vagrant up)
        (cd "$SRC" && vagrant package --output "$box")
        (cd "$SRC" && vagrant destroy -f)
        echo "    wrote $box"
    fi
    if [ ! -f "$box" ]; then
        echo "    ERROR: no provisioned box at $box — the challenge's provisioning script" >&2
        echo "    IS the answer key (see CLAUDE.md), so a candidate bundle can't ship it." >&2
        echo "    Re-run with --build-box first." >&2
        return 1
    fi

    local stage; stage=$(mktemp -d)
    # Minimal, self-contained Vagrantfile: no require_relative "shared/base",
    # no provisioning step, no Packer dependency — just the network/provider
    # settings a candidate needs to boot the pre-provisioned box.
    cat > "$stage/Vagrantfile" <<EOF
Vagrant.configure("2") do |config|
  config.vm.box = "ccdc/${NAME}-candidate"
  config.vm.guest = :windows
  config.vm.communicator = "winrm"
  config.winrm.username = "vagrant"
  config.winrm.password = "vagrant"
  config.winrm.timeout = 300
  config.winrm.retry_limit = 20
  config.vm.network "private_network", ip: "192.168.56.10"
  config.vm.network "forwarded_port", guest: 3389, host: 3389, id: "rdp", auto_correct: true
  config.vm.provider "virtualbox" do |v|
    v.memory = 4096
    v.cpus = 2
    v.gui = false
  end
end
EOF
    cp "$SRC/README.md" "$stage/README.md"
    cat > "$stage/SETUP.md" <<EOF
# Setup

This candidate bundle ships without a provisioning script — the box is
already provisioned. Alongside this zip you should have received
\`${NAME}-provisioned.box\` (a separate, large file).

1. \`vagrant box add ccdc/${NAME}-candidate /path/to/${NAME}-provisioned.box\`
2. \`vagrant up\`
3. Follow README.md's Connect section.
EOF
    rm -f "$DIST/${NAME}-candidate.zip"
    (cd "$stage" && zip -rq "$DIST/${NAME}-candidate.zip" .)
    rm -rf "$stage"
    echo "    wrote dist/${NAME}-candidate.zip (small — ships alongside $box, not inside it)"
}

case "$BUNDLE" in
    instructor) package_instructor ;;
    candidate)
        case "$FAMILY" in
            docker) package_candidate_docker ;;
            linux-vm) package_candidate_linux_vm ;;
            windows) package_candidate_windows ;;
        esac
        ;;
    both)
        package_instructor
        case "$FAMILY" in
            docker) package_candidate_docker ;;
            linux-vm) package_candidate_linux_vm ;;
            windows) package_candidate_windows ;;
        esac
        ;;
    *) echo "ERROR: --bundle must be candidate, instructor, or both" >&2; exit 1 ;;
esac
