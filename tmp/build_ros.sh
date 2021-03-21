# download source code from github repo
# download source code from github
pushd .
git clone  https://github.com/tiiuae/fog_sw.git --recursive
cd fog_sw
git submodule update --init --recursive
popd
pushd .
