package lib

import (
	log "github.com/sirupsen/logrus"
)

func EnableDebugLog(debug bool) {
	if debug == true {
		log.Info("Enabled debug logging")
		log.SetLevel(log.DebugLevel)
	} else {
		log.SetLevel(log.InfoLevel)
	}
}
