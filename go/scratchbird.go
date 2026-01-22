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
	return d.OpenConnector(name).Connect(context.Background())
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
