## redis stack with SSL enabled for on kubernetes experiement 
---

1. Generate cert to run redis with SSL

sh
```
    ./startup.sh
```

2. Build docker image with SSL enabled

sh
```
    ./ci_cd_build.sh
```