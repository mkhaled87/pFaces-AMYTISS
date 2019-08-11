SUBDIRS = kernel

.PHONY: all clean push pull

all: check-pfaces-sdk
	for dir in $(SUBDIRS); do $(MAKE) all -C $$dir $@; done

clean:
	rm -f ./kernel-pack/*.log
	rm -f ./kernel-pack/*.render
	rm -f ./kernel-pack/*.driver
	rm -f ./kernel-pack/*.dll
	rm -f ./kernel-pack/*.so
	rm -f ./kernel-pack/*.exp
	rm -f ./kernel-pack/*.ilk
	rm -f ./kernel-pack/*.lib
	rm -f ./kernel-pack/*.pdb
	rm -f ./kernel-pack/*.ipdb
	rm -f ./kernel-pack/*.iobj
	find . -name "*.raw" -type f -delete
	for dir in $(SUBDIRS); do $(MAKE) clean -C $$dir $@; done


check-pfaces-sdk:
ifndef PFACES_SDK_ROOT
	$(error Are you sure you installed pFaces ? PFACES_SDK_ROOT is not defined.)
endif

pull:
	git pull
	
push: pull
	git add -A .
	git commit -m"Automated commit from the Makeflle"
	git push


	