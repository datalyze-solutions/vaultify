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

	"github.com/datalyze-solutions/vaultify/lib"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

// runCmd represents the run command
var runCmd = &cobra.Command{
	Use:   "run-only",
	Short: "Replaces prepared envs and runs the passed command",
	Long: `A longer description that spans multiple lines and likely contains examples
	and usage of using your command. For example:

	Cobra is a CLI library for Go that empowers applications.
	This application is a tool to generate the needed files
	to quickly create a Cobra application.`,

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

		shellCommandArgs, _ := lib.ShellCommandArgs(os.Args, cmd.CalledAs())
		lib.ExecGivenShellCommand(shellCommandArgs, os.Environ())
		return
	},
}

func init() {
	RootCmd.AddCommand(runCmd)
}
