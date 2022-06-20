#! /bin/bash

_HOME2_=$(dirname $0)
export _HOME2_
_HOME_=$(cd $_HOME2_;pwd)
export _HOME_

echo $_HOME_
cd $_HOME_



build_for='ubuntu_18.04'
aar_dir=$_HOME_/"$build_for"/artefacts
aar_file=$aar_dir/data-release.aar
version="0.4.2.104"

rm -Rf ./tmp/
mkdir -p ./tmp/
cp -av .m2 ./tmp/

mv tmp/.m2/repository/info/guardianproject/iocipher/IOCipher2/0.4.2 tmp/.m2/repository/info/guardianproject/iocipher/IOCipher2/"$version"
mv tmp/.m2/repository/info/guardianproject/iocipher/IOCipher2/"$version"/IOCipher2-0.4.2.pom \
   tmp/.m2/repository/info/guardianproject/iocipher/IOCipher2/"$version"/IOCipher2-"$version".pom
rm tmp/.m2/repository/info/guardianproject/iocipher/IOCipher2/"$version"/IOCipher2-0.4.2.aar
cp -av "$aar_file" tmp/.m2/repository/info/guardianproject/iocipher/IOCipher2/"$version"/IOCipher2-"$version".aar

sed -i -e 's#0.4.2#'"$version"'#g' tmp/.m2/repository/info/guardianproject/iocipher/IOCipher2/maven-metadata-local.xml
sed -i -e 's#0.4.2#'"$version"'#g' tmp/.m2/repository/info/guardianproject/iocipher/IOCipher2/"$version"/IOCipher2-"$version".pom

cd tmp/
zip -r local_maven_iocipher_"$version".zip .m2

echo "##########################"
echo ""
ls -al $(pwd)/local_maven_iocipher_"$version".zip
echo ""
echo "##########################"
