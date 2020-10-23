// MIT License
// Copyright (c) 2020 Datalyze Solutions m.ludwig@datalyze-solutions.com

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

package cmd

import (
	"os"

	"github.com/datalyze-solutions/vaultify/debug"
	"github.com/datalyze-solutions/vaultify/lib"
	"github.com/spf13/cobra"

	log "github.com/sirupsen/logrus"
)

var (
	patternPrefix string = "<<"
	patternSuffix string = ">>"
)

// runAndReplaceCmd represents the run command
var runAndReplaceCmd = &cobra.Command{
	Use:   "run",
	Short: "Replaces prepared envs with vault values and runs the passed command",
	Long: `Replaces prepared environment variables with vault extracted values
	and executes the passed shell command. For example:

	export TEST_ENV="<<TEST_VALUE_INSIDE_VAULT>>"
	vaultify run sh
	$ export | grep TEST_ENV
	`,

	// the flag of given shell commands `ls -alh` -> `-alh`
	// will be parsed like command flags.
	// DisableFlagParsing prevents this.
	// Take care to manually parse the RootCommands flags or
	// to set RootCommand.DisableFlagParsing: false and RootCommand.TraverseChildren: true
	DisableFlagParsing: true,
	RunE: func(cmd *cobra.Command, args []string) (err error) {
		defer func() {
			if r := recover(); r != nil {
				err = r.(error)
				log.Debugf("Error: %+v\n\n", err)
			}
		}()

		RootCmd.ParseFlags(args)
		lib.EnableDebugLog(Debug)
		debug.DemoMode(Demo, DemoWithErrors)

		updatedEnvs, _ := lib.ReplaceVaultValuesInOSEnvs(VaultFile, VaultKeyFile, patternPrefix, patternSuffix)
		envs := append(
			os.Environ(),
			updatedEnvs...,
		)

		shellCommandArgs, _ := lib.ShellCommandArgs(os.Args, cmd.CalledAs())
		lib.ExecGivenShellCommand(shellCommandArgs, envs)
		return
	},
}

func init() {
	RootCmd.AddCommand(runAndReplaceCmd)

	// runAndReplaceCmd.Flags().StringVarP(&patternPrefix, "patternPrefix", "P", "<<", "Prefix template string")
	// runAndReplaceCmd.Flags().StringVarP(&patternSuffix, "patternSuffix", "S", ">>", "Suffix template string")
}
