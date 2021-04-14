package main

import (
	"log"

	"github.com/volatiletech/sqlboiler/v4/drivers"
	"github.com/volatiletech/sqlboiler/v4/drivers/sqlboiler-psql/driver"
)

func main() {
	log.Println("Running the forked psql driver (github.com/theo-m/sqlboiler)")
	drivers.DriverMain(&driver.PostgresDriver{})
}
