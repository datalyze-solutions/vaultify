package lib

import (
	"io/ioutil"
	"strings"

	log "github.com/sirupsen/logrus"

	"github.com/pbthorste/avtool"
)

func ReadVaultKey(vaultKey string) string {
	content, err := ioutil.ReadFile(vaultKey)
	if err != nil {
		log.Fatal(err)
	}

	text := string(content)
	text = strings.TrimSuffix(text, "\n")

	return text
}

func DecryptVaultFile(file string, pw string) (string, error) {
	result, err := avtool.DecryptFile(file, pw)

	if err != nil {
		if strings.Contains(err.Error(), "runtime error: index out of range") == true {
			panic(invalidVaultFile(file))
		} else if strings.Contains(err.Error(), "ERROR: digests do not match - exiting") == true {
			panic(invalidVaultKeyFile())
		} else {
			panic(err)
		}
	}
	return result, nil
}

func BuildVaultMap(vaultFileContent string) map[string]string {

	var vaultMap = make(map[string]string)

	resultSplitted := strings.SplitN(vaultFileContent, "\n", -1)
	for _, value := range resultSplitted {
		vaultPair := strings.SplitN(value, "=", -1)

		if len(vaultPair) > 1 {
			vaultKey := vaultPair[0]
			vaultValue := vaultPair[1]
			vaultMap[vaultKey] = vaultValue
		}
	}

	return vaultMap
}

func ReadVaultFileContent(vaultFile string, vaultKeyFile string) (string, error) {
	vaultKeyValue := ReadVaultKey(vaultKeyFile)

	vaultFileContent, err := DecryptVaultFile(vaultFile, vaultKeyValue)
	if err != nil {
		panic(err)
	}

	return vaultFileContent, nil
}
