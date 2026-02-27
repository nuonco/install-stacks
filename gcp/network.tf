resource "google_compute_network" "main" {
  name                    = "${local.prefix}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "public" {
  name                     = "${local.prefix}-public-subnet"
  region                   = local.region
  network                  = google_compute_network.main.id
  ip_cidr_range            = "10.128.0.0/24"
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "private" {
  name                     = "${local.prefix}-private-subnet"
  region                   = local.region
  network                  = google_compute_network.main.id
  ip_cidr_range            = "10.128.1.0/24"
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "runner" {
  name                     = "${local.prefix}-runner-subnet"
  region                   = local.region
  network                  = google_compute_network.main.id
  ip_cidr_range            = "10.128.2.0/24"
  private_ip_google_access = true
}

resource "google_compute_router" "main" {
  name    = "${local.prefix}-router"
  region  = local.region
  network = google_compute_network.main.id
}

resource "google_compute_router_nat" "main" {
  name                               = "${local.prefix}-nat"
  router                             = google_compute_router.main.name
  region                             = local.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_firewall" "allow_internal" {
  name    = "${local.prefix}-allow-internal"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.128.0.0/16"]
}

resource "google_compute_firewall" "allow_egress" {
  name      = "${local.prefix}-allow-egress"
  network   = google_compute_network.main.name
  direction = "EGRESS"

  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
}
