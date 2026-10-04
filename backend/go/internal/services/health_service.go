package services

// HealthStatus represents the health payload.
type HealthStatus struct {
	Status  string `json:"status"`
	Service string `json:"service"`
	Version string `json:"version"`
}

// HealthService defines operations for checking application health.
type HealthService interface {
	Check() HealthStatus
}

type healthService struct {
	version string
}

// NewHealthService instantiates a HealthService.
func NewHealthService(version string) HealthService {
	return &healthService{version: version}
}

func (s *healthService) Check() HealthStatus {
	return HealthStatus{
		Status:  "ok",
		Service: "morphpdf",
		Version: s.version,
	}
}
