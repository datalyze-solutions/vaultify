package debug

import "os"

func DemoMode(demo bool, demoWithErrors bool) {
	if demo == true {
		setDemoOsVars()
	}
	if demoWithErrors == true {
		setDemoErroneousOsVars()
	}
}

func setDemoOsVars() {
	os.Setenv("VAULTIFY_DB_PASSWORD", "{{DB_PASSWORD}}")
	os.Setenv("VAULTIFY_TEST", "{{TEST}}")
	os.Setenv("VAULTIFY_POSTGRES_PASSWORD", "{{DB_PASSWORD}}")
	os.Setenv("VAULTIFY_DB_URI", "postgres://{{DB_USER}}:{{DB_PASSWORD}}@{{DB_HOST}}:{{DB_PORT}}/{{DB_NAME}}")
	os.Setenv("VAULTIFY_ALTERNATIVE_TEST", "<<TEST>>")
}

func setDemoErroneousOsVars() {
	os.Setenv("VAULTIFY_INEXITING_VALUE", "{{I_DO_NOT_EXIST}}")
}
