// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
package scratchbird

import (
	"context"
	"database/sql"
	"database/sql/driver"
)

func init() {
	sql.Register("scratchbird", &Driver{})
}

type Driver struct{}

func (d *Driver) Open(name string) (driver.Conn, error) {
	connector, err := d.OpenConnector(name)
	if err != nil {
		return nil, err
	}
	return connector.Connect(context.Background())
}

func (d *Driver) OpenConnector(name string) (driver.Connector, error) {
	cfg, err := ParseConfig(name)
	if err != nil {
		return nil, err
	}
	return &Connector{config: cfg}, nil
}

type Connector struct {
	config Config
}

func (c *Connector) Connect(ctx context.Context) (driver.Conn, error) {
	conn := &Conn{config: c.config}
	if err := conn.connect(ctx); err != nil {
		return nil, err
	}
	return conn, nil
}

func (c *Connector) Driver() driver.Driver {
	return &Driver{}
}
