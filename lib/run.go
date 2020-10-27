package lib

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
	"syscall"
)

func ReplaceVaultValuesInOSEnvs(vaultFile string, vaultKeyFile string, patternPrefix string, patternSuffix string) ([]string, error) {
	// vaultKeyValue := ReadVaultKey(vaultKeyFile)

	// vaultFileContent, err := DecryptVaultFile(vaultFile, vaultKeyValue)
	// if err != nil {
	// 	panic(err)
	// }

	vaultFileContent, _ := ReadVaultFileContent(vaultFile, vaultKeyFile)
	vaultMap := BuildVaultMap(vaultFileContent)

	updatedEnvs := replaceVaultValuesInOSEnvs(os.Environ(), vaultMap, patternPrefix, patternSuffix)
	return updatedEnvs, nil
}

func ExecGivenShellCommandInSubshell(args []string, envs []string) (err error) {
	wrapped := fmt.Sprintf(`%s`, strings.Join(args, " "))
	shellCommandArgs := []string{"sh", "-c", wrapped}
	err = ExecGivenShellCommand(shellCommandArgs, envs)
	if err != nil {
		return err
	}
	return
}

func ExecGivenShellCommand(args []string, envs []string) (err error) {
	if len(args) == 0 {
		panic(noShellCommandGiven())
	}

	cmd := args[0]

	binary, lookErr := exec.LookPath(cmd)
	if lookErr != nil {
		panic(executableNotFound(cmd))
	}

	cmdArgs := args[0:]
	err = syscall.Exec(binary, cmdArgs, envs)
	if err != nil {
		return err
	}
	return
}
