package config

// Configuration exported
type AppConfiguration struct {
	Port     int `env:"PORT,default=8080"`
	Database DatabaseConfiguration
}

// DatabaseConfiguration exported
type DatabaseConfiguration struct {
	Type           string `env:"RETAIL_CATALOG_PERSISTENCE_PROVIDER,default=in-memory"`
	Endpoint       string `env:"RETAIL_CATALOG_PERSISTENCE_ENDPOINT"`
	Name           string `env:"RETAIL_CATALOG_PERSISTENCE_DB_NAME,default=retailstore"`
	User           string `env:"RETAIL_CATALOG_PERSISTENCE_USER,default=retailstore"`
	Password       string `env:"RETAIL_CATALOG_PERSISTENCE_PASSWORD"`
	ConnectTimeout int    `env:"RETAIL_CATALOG_PERSISTENCE_CONNECT_TIMEOUT,default=5"`
}
