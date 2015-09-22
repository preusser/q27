PKG := me/preusser/q27

.PHONY: all clean clobber

all: q27local.jar q27server.jar q27client.jar
q27local.jar: $(PKG)/*.java
	$(MAKE) clean; \
	javac $(PKG)/LocalMain.java && \
	jar cfe $@ $(subst /,.,$(PKG)).LocalMain $(PKG)/*.class
q27server.jar: $(PKG)/*.java
	$(MAKE) clean; \
	javac $(PKG)/Server.java && \
	jar cfe $@ $(subst /,.,$(PKG)).Server $(PKG)/*.class
q27client.jar: $(PKG)/*.java
	$(MAKE) clean; \
	javac $(PKG)/Client.java && \
	jar cfe $@ $(subst /,.,$(PKG)).Client $(PKG)/*.class

# Cleaning up
clean:
	rm -f $(PKG)/*.class
clobber: clean
	rm -rf q27local.jar q27server.jar q27client.jar
