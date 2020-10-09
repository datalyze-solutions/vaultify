package lib

func findCommandNameIndex(args []string, cmdName string) int {
	var cmdNameIndex int = 0
	for i, arg := range args {
		if arg == cmdName {
			cmdNameIndex = i
		}
	}

	return cmdNameIndex
}

// find command keyword "run" and split os.Args at this index
func ShellCommandArgs(args []string, cmdName string) ([]string, error) {
	var shellCommandArgs []string
	cmdNameIndex := findCommandNameIndex(args, cmdName)

	if len(args) > cmdNameIndex {
		index := cmdNameIndex + 1
		shellCommandArgs = append(shellCommandArgs, args[index:]...)
	}
	// log.Debug("Given shell command: ", shellCommandArgs)

	return shellCommandArgs, nil
}
