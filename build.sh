#!/bin/bash

version=$1
REGISTRY_USERNAME=$2
REGISTRY_TOKEN=$3

echo "create a build container"
buildcon=$(buildah from mcr.microsoft.com/dotnet/sdk:5.0)
buildah config --workingdir /scr $buildcon
buildah copy $buildcon ./simple-app.csproj ./
buildah run $buildcon dotnet restore ./simple-app.csproj
buildah copy $buildcon ./ ./
buildah run $buildcon dotnet publish ./simple-app.csproj -c Release -o /app/publish
buildconmount=$(buildah mount $buildcon)
echo $buildconmount

echo "create a final container"
finalcon=$(buildah from mcr.microsoft.com/dotnet/aspnet:5.0)
buildah config --workingdir /app $finalcon
buildah config --port 80 $finalcon
buildah config --port 443 $finalcon
finalconmount=$(buildah mount $finalcon)
echo $finalconmount

cp -r $buildconmount/app/publish $finalconmount/app

buildah config --entrypoint 'dotnet simple-app.dll' $finalcon

echo "commit an image"
buildah commit $finalcon simple-app:$version

echo "cleanup"
buildah umount --all
buildah rm --all

echo "push to github"
buildah push --creds $REGISTRY_USERNAME:$REGISTRY_TOKEN localhost/simple-app:$version docker://ghcr.io/$REGISTRY_USERNAME/simple-app:$version
buildah push --creds $REGISTRY_USERNAME:$REGISTRY_TOKEN localhost/simple-app:$version docker://ghcr.io/$REGISTRY_USERNAME/simple-app:latest













