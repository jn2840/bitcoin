Release Process
====================

* update translations (ping wumpus, Diapolo or tcatm on IRC)
* see https://github.com/beardcoin/beardcoin/blob/master/doc/translation_process.md#syncing-with-transifex

* * *

###first time only or for new builders, check out the source in the following directory hierarchy

	cd /path/to/your/toplevel/build
	git clone https://github.com/beardcoin/gitian.sigs.git
	git clone https://github.com/devrandom/gitian-builder.git
	git clone https://github.com/beardcoin/beardcoin.git

###for beardcoin maintainers/release engineers, update (commit) version in sources

	pushd ./beardcoin
	contrib/verifysfbinaries/verify.sh
	doc/README*
	share/setup.nsi
	src/clientversion.h (change CLIENT_VERSION_IS_RELEASE to true)

###for beardcoin maintainers/release engineers, tag version in git

	git tag -s v(new version, e.g. 0.8.0)

###for beardcoin maintainers/release engineers, write release notes. git shortlog helps a lot, for example:

	git shortlog --no-merges v(current version, e.g. 0.7.2)..v(new version, e.g. 0.8.0)
	popd

* * *

###update gitian, gitian.sigs, checkout beardcoin version, and perform gitian builds

 To ensure your gitian descriptors are accurate for direct reference for gbuild, below, run the following from a directory containing the beardcoin source:
  
	pushd ./beardcoin
	export SIGNER=(your gitian key, ie bluematt, sipa, etc)
	export VERSION=(new version, e.g. 0.8.0)
	git checkout v${VERSION}
	popd

  Ensure your gitian.sigs are up-to-date if you wish to gverify your builds against other gitian signatures:

	pushd ./gitian.sigs
	git pull
	popd

  Ensure your gitian-builder sources are up-to-date to take advantage of the new caching features of gitian (`e9741525c` or later is recommended)

	pushd ./gitian-builder
	git pull

###fetch and create inputs: (first time, or when dependency versions change)
 
	mkdir -p inputs
	wget -P inputs https://bitcoincore.org/cfields/osslsigncode-Backports-to-1.7.1.patch
	wget -P inputs http://downloads.sourceforge.net/project/osslsigncode/osslsigncode/osslsigncode-1.7.1.tar.gz

 Register and download the Apple SDK: (see OSX Readme for details)
 
 https://developer.apple.com/devcenter/download.action?path=/Developer_Tools/xcode_6.1.1/xcode_6.1.1.dmg
 
 Using a Mac, create a tarball for the 10.9 SDK and copy it to the inputs directory:
 
	tar -C /Volumes/Xcode/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/ -czf MacOSX10.9.sdk.tar.gz MacOSX10.9.sdk

###Optional: Seed the Gitian sources cache and offline git repositories

By default, gitian will fetch source files as needed. To cache them ahead of time:

	make -C ../beardcoin/depends download SOURCES_PATH=`pwd`/cache/common

Only missing files will be fetched, so this is safe to re-run for each build.

Clone the detached-sigs repository:

	popd
	git clone https://github.com/beardcoin/beardcoin-detached-sigs.git
	pushd ./beardcoin-builder

NOTE: Offline builds must use the --url flag to ensure gitian fetches only from local URLs.
For example: ./bin/bguild --url beardcoin=/path/to/beardcoin,signature=/path/to/sigs {rest of arguments}
The following gbuild invocations DO NOT DO THIS by default.

###Build (and optionally verify) Beardcoin Core for Linux, Windows, and OS X:
  
	./bin/gbuild --commit beardcoin=v${VERSION} ../beardcoin/contrib/gitian-descriptors/gitian-linux.yml
	./bin/gsign --signer $SIGNER --release ${VERSION}-linux --destination ../gitian.sigs/ ../beardcoin/contrib/gitian-descriptors/gitian-linux.yml
	./bin/gverify -v -d ../gitian.sigs/ -r ${VERSION}-linux ../beardcoin/contrib/gitian-descriptors/gitian-linux.yml
	mv build/out/beardcoin-*.tar.gz build/out/src/beardcoin-*.tar.gz ../

	./bin/gbuild --commit beardcoin=v${VERSION} ../beardcoin/contrib/gitian-descriptors/gitian-win.yml
	./bin/gsign --signer $SIGNER --release ${VERSION}-win-unsigned --destination ../gitian.sigs/ ../beardcoin/contrib/gitian-descriptors/gitian-win.yml
	./bin/gverify -v -d ../gitian.sigs/ -r ${VERSION}-win-unsigned ../beardcoin/contrib/gitian-descriptors/gitian-win.yml
	mv build/out/beardcoin-*-win-unsigned.tar.gz inputs/beardcoin-win-unsigned.tar.gz
	mv build/out/beardcoin-*.zip build/out/beardcoin-*.exe ../

	./bin/gbuild --commit beardcoin=v${VERSION} ../beardcoin/contrib/gitian-descriptors/gitian-osx.yml
	./bin/gsign --signer $SIGNER --release ${VERSION}-osx-unsigned --destination ../gitian.sigs/ ../beardcoin/contrib/gitian-descriptors/gitian-osx.yml
	./bin/gverify -v -d ../gitian.sigs/ -r ${VERSION}-osx-unsigned ../beardcoin/contrib/gitian-descriptors/gitian-osx.yml
	mv build/out/beardcoin-*-osx-unsigned.tar.gz inputs/beardcoin-osx-unsigned.tar.gz
	mv build/out/beardcoin-*.tar.gz build/out/beardcoin-*.dmg ../
	popd

  Build output expected:

  1. source tarball (beardcoin-${VERSION}.tar.gz)
  2. linux 32-bit and 64-bit dist tarballs (beardcoin-${VERSION}-linux[32|64].tar.gz)
  3. windows 32-bit and 64-bit unsigned installers and dist zips (beardcoin-${VERSION}-win[32|64]-setup-unsigned.exe, beardcoin-${VERSION}-win[32|64].zip)
  4. OSX unsigned installer and dist tarball (beardcoin-${VERSION}-osx-unsigned.dmg, beardcoin-${VERSION}-osx64.tar.gz)
  5. Gitian signatures (in gitian.sigs/${VERSION}-<linux|{win,osx}-unsigned>/(your gitian key)/

###Next steps:

Commit your signature to gitian.sigs:

	pushd gitian.sigs
	git add ${VERSION}-linux/${SIGNER}
	git add ${VERSION}-win-unsigned/${SIGNER}
	git add ${VERSION}-osx-unsigned/${SIGNER}
	git commit -a
	git push  # Assuming you can push to the gitian.sigs tree
	popd

  Wait for Windows/OSX detached signatures:
	Once the Windows/OSX builds each have 3 matching signatures, they will be signed with their respective release keys.
	Detached signatures will then be committed to the beardcoin-detached-sigs repository, which can be combined with the unsigned apps to create signed binaries.

  Create (and optionally verify) the signed OSX binary:

	pushd ./gitian-builder
	./bin/gbuild -i --commit signature=v${VERSION} ../beardcoin/contrib/gitian-descriptors/gitian-osx-signer.yml
	./bin/gsign --signer $SIGNER --release ${VERSION}-osx-signed --destination ../gitian.sigs/ ../beardcoin/contrib/gitian-descriptors/gitian-osx-signer.yml
	./bin/gverify -v -d ../gitian.sigs/ -r ${VERSION}-osx-signed ../beardcoin/contrib/gitian-descriptors/gitian-osx-signer.yml
	mv build/out/beardcoin-osx-signed.dmg ../beardcoin-${VERSION}-osx.dmg
	popd

  Create (and optionally verify) the signed Windows binaries:

	pushd ./gitian-builder
	./bin/gbuild -i --commit signature=v${VERSION} ../beardcoin/contrib/gitian-descriptors/gitian-win-signer.yml
	./bin/gsign --signer $SIGNER --release ${VERSION}-win-signed --destination ../gitian.sigs/ ../beardcoin/contrib/gitian-descriptors/gitian-win-signer.yml
	./bin/gverify -v -d ../gitian.sigs/ -r ${VERSION}-win-signed ../beardcoin/contrib/gitian-descriptors/gitian-win-signer.yml
	mv build/out/beardcoin-*win64-setup.exe ../beardcoin-${VERSION}-win64-setup.exe
	mv build/out/beardcoin-*win32-setup.exe ../beardcoin-${VERSION}-win32-setup.exe
	popd

Commit your signature for the signed OSX/Windows binaries:

	pushd gitian.sigs
	git add ${VERSION}-osx-signed/${SIGNER}
	git add ${VERSION}-win-signed/${SIGNER}
	git commit -a
	git push  # Assuming you can push to the gitian.sigs tree
	popd

-------------------------------------------------------------------------

### After 3 or more people have gitian-built and their results match:

- Create `SHA256SUMS.asc` for the builds, and GPG-sign it:
```bash
sha256sum * > SHA256SUMS
gpg --digest-algo sha256 --clearsign SHA256SUMS # outputs SHA256SUMS.asc
rm SHA256SUMS
```
(the digest algorithm is forced to sha256 to avoid confusion of the `Hash:` header that GPG adds with the SHA256 used for the files)
Note: check that SHA256SUMS itself doesn't end up in SHA256SUMS, which is a spurious/nonsensical entry.

- Upload zips and installers, as well as `SHA256SUMS.asc` from last step, to the beardcoin.org server
  into `/var/www/bin/beardcoin-core-${VERSION}`

- Update beardcoin.org version

  - First, check to see if the Beardcoin.org maintainers have prepared a
    release: https://github.com/beardcoin/beardcoin.org/labels/Releases

      - If they have, it will have previously failed their Travis CI
        checks because the final release files weren't uploaded.
        Trigger a Travis CI rebuild---if it passes, merge.

  - If they have not prepared a release, follow the Beardcoin.org release
    instructions: https://github.com/beardcoin/beardcoin.org#release-notes

  - After the pull request is merged, the website will automatically show the newest version within 15 minutes, as well
    as update the OS download links. Ping @saivann/@harding (saivann/harding on Freenode) in case anything goes wrong

- Announce the release:

  - Release sticky on bitcointalk: https://bitcointalk.org/index.php?board=1.0

  - Beardcoin-development mailing list

  - Update title of #beardcoin on Freenode IRC

  - Optionally reddit /r/Beardcoin, ... but this will usually sort out itself

- Notify BlueMatt so that he can start building [https://launchpad.net/~beardcoin/+archive/ubuntu/beardcoin](the PPAs)

- Add release notes for the new version to the directory `doc/release-notes` in git master

- Celebrate
