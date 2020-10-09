package lib

import (
	"fmt"
	"regexp"
	"strings"
)

func replaceVaultValuesInOSEnvs(envs []string, vaultMap map[string]string, patternPrefix string, patternSuffix string) []string {

	var updatedEnvs []string

	for _, env := range envs {
		envPair := strings.SplitN(env, "=", 2)
		key := envPair[0]
		value := envPair[1]

		pattern := fmt.Sprintf(`%s.*?%s`, patternPrefix, patternSuffix)
		re := regexp.MustCompile(pattern)
		submatchall := re.FindAllString(value, -1)

		if len(submatchall) > 0 {
			// log.Debug(submatchall)
			// log.Debugf("old value of %s: %s\n", key, os.Getenv(key))
			for _, placeholder := range submatchall {
				var replacementKey = strings.Trim(placeholder, patternPrefix)
				replacementKey = strings.Trim(replacementKey, patternSuffix)

				replacementValue, ok := vaultMap[replacementKey]
				if ok != true {
					panic(vaultKeyNotFound(replacementKey))
				}
				value = strings.Replace(value, placeholder, replacementValue, -1)
			}
			updatedEnvs = append(updatedEnvs, fmt.Sprintf("%s=%s", key, value))

			// log.Debugf("new value of %s: %s\n", key, os.Getenv(key))
			// log.Debug()
		}
	}

	// log.Debug(updatedEnvs)
	return updatedEnvs
}
