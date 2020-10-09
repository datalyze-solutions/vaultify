package lib

import (
	"github.com/pkg/errors"
)

func noShellCommandGiven() error {
	return errors.New("No shell command given")
}

func executableNotFound(cmd string) error {
	return errors.New("Can't find executable: " + cmd)
}

func vaultKeyNotFound(key string) error {
	return errors.New("Can't find vault key: " + key)
}

func invalidVaultFile(file string) error {
	return errors.New("Invalid vault file or not a vault file: " + file)
}

func invalidVaultKeyFile() error {
	return errors.New("Invalid vault key file or key file content is wrong")
}
