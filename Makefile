install:
	pod install --project-directory=Example
update:
	pod update Vespucci --project-directory=Example
push:
	git push --all
	git push --tags
	pod trunk push