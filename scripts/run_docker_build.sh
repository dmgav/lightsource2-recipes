#!/usr/bin/env bash

# NOTE: This script has been adapted from content generated by github.com/conda-forge/conda-smithy

REPO_ROOT=$(cd "$(dirname "$0")/.."; pwd;)
IMAGE_NAME="ericdill/debian-conda-builder:latest"
docker pull $IMAGE_NAME
upload_channel=lightsource2-tag-test
config=$(cat <<CONDARC

channels:
 - $upload_channel
 - conda-forge
 - defaults

always_yes: true
show_channel_urls: True

CONDARC
)

cat << EOF | docker run -i \
                        -v ${REPO_ROOT}/nonpy:/nonpy-recipes \
                        -v ${REPO_ROOT}/py2:/py2-recipes \
                        -v ${REPO_ROOT}/py3:/py3-recipes \
                        -v ${REPO_ROOT}/py35:/py35-recipes \
                        -v ${REPO_ROOT}/pyall:/pyall-recipes \
                        -v ${REPO_ROOT}/sort-of-dev-but-actually-tag/py3:/py3-dev \
                        -a stdin -a stdout -a stderr \
                        $IMAGE_NAME \
                        bash || exit $?

set -e
if [ "${BINSTAR_TOKEN}" ];then
    export BINSTAR_TOKEN=${BINSTAR_TOKEN}
fi

git clone https://github.com/scikit-beam/skbeam-recipes /tmp/skbeam-recipes

# Unused, but needed by conda-build currently... :(
export CONDA_NPY='110'

export PYTHONUNBUFFERED=1
echo "$config" > ~/.condarc

conda install conda-build
conda install mock --yes
pip install https://github.com/ericdill/conda-build-all/zipball/include-test-deps#egg=conda-build-all
pip install https://github.com/ericdill/conda-build-utils/zipball/master#egg=conda-build-utils
conda info

# dont allow failures on the conda-build commands
set -e
build_from_yaml /repo/build-directive.yaml -u $USERNAME
# These are some standard tools. But they aren't available to a recipe at this point (we need to figure out how a recipe should define OS level deps)
#yum install -y expat-devel git autoconf libtool texinfo check-devel
#
# echo "
#
# ===== BUILDING SCIKIT-BEAM RECIPES =====
#
# "
# conda-build-all /tmp/skbeam-recipes/recipes --upload-channels $upload_channel --matrix-conditions "numpy >=1.10,<1.11" "python >=2.7,<3|>=3.4" --inspect-channels $upload_channel
#
# echo "
#
# ===== BUILDING NONPY =====
#
# "
# conda-build-all /nonpy-recipes --upload-channels $upload_channel --inspect-channels $upload_channel --matrix-conditions "python >=3.5"
#
# echo "
#
# ===== BUILDING PY2 =====
#
# "
# conda-build-all /py2-recipes --upload-channels $upload_channel --matrix-conditions "numpy >=1.10,<1.11" "python >=2.7,<3" --inspect-channels $upload_channel
#
# echo "
#
# ===== BUILDING PY2&PY3 =====
#
# "
# conda-build-all /pyall-recipes --upload-channels $upload_channel --matrix-conditions "numpy >=1.10,<1.11" "python >=2.7,<3|>=3.4" --inspect-channels $upload_channel
#
# echo "
#
# ===== BUILDING PY3 =====
#
# "
# conda-build-all /py3-recipes --upload-channels $upload_channel --matrix-conditions "numpy >=1.10,<1.11" "python >=3.4" --inspect-channels $upload_channel
#
# echo "
#
# ===== BUILDING PY3 =====
#
# "
# conda-build-all /py3-recipes --upload-channels $upload_channel --matrix-conditions "numpy >=1.10,<1.11" "python >=3.4" --inspect-channels $upload_channel
#
# echo "========== Running sort-of-dev-but-actually-tag builds =========="
# devbuild /py3-dev --username $upload_channel --pyver 3.4 3.5
#
EOF
