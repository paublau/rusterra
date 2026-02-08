-- RustEarthTerritory - initial schema
-- Compatible target: MySQL 8+ (and adaptable to SQLite)

CREATE TABLE IF NOT EXISTS countries (
    country_id        VARCHAR(32) PRIMARY KEY,
    name              VARCHAR(128) NOT NULL,
    is_active         TINYINT(1) NOT NULL DEFAULT 1,
    created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS seasons (
    season_id         BIGINT PRIMARY KEY,
    start_at          DATETIME NOT NULL,
    end_at            DATETIME NULL,
    wipe_type         VARCHAR(32) NOT NULL,
    status            VARCHAR(32) NOT NULL,
    created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS territories (
    region_id         VARCHAR(32) PRIMARY KEY,
    owner_country_id  VARCHAR(32) NULL,
    control_score     INT NOT NULL DEFAULT 0,
    version           BIGINT NOT NULL DEFAULT 0,
    last_capture_at   DATETIME NULL,
    updated_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_territories_country
        FOREIGN KEY (owner_country_id) REFERENCES countries(country_id)
        ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS player_country_membership (
    id                BIGINT AUTO_INCREMENT PRIMARY KEY,
    player_id         VARCHAR(64) NOT NULL,
    country_id        VARCHAR(32) NOT NULL,
    active            TINYINT(1) NOT NULL DEFAULT 1,
    assigned_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    unassigned_at     DATETIME NULL,
    source            VARCHAR(32) NOT NULL,
    CONSTRAINT fk_pcm_country
        FOREIGN KEY (country_id) REFERENCES countries(country_id)
        ON DELETE RESTRICT,
    INDEX idx_pcm_player_active (player_id, active)
);

CREATE TABLE IF NOT EXISTS capture_events (
    id                BIGINT AUTO_INCREMENT PRIMARY KEY,
    region_id         VARCHAR(32) NOT NULL,
    from_country_id   VARCHAR(32) NULL,
    to_country_id     VARCHAR(32) NULL,
    reason            VARCHAR(32) NOT NULL,
    actor_player_id   VARCHAR(64) NULL,
    season_id         BIGINT NULL,
    metadata_json     TEXT NULL,
    created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_capture_region
        FOREIGN KEY (region_id) REFERENCES territories(region_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_capture_from_country
        FOREIGN KEY (from_country_id) REFERENCES countries(country_id)
        ON DELETE SET NULL,
    CONSTRAINT fk_capture_to_country
        FOREIGN KEY (to_country_id) REFERENCES countries(country_id)
        ON DELETE SET NULL,
    CONSTRAINT fk_capture_season
        FOREIGN KEY (season_id) REFERENCES seasons(season_id)
        ON DELETE SET NULL,
    INDEX idx_capture_region_created (region_id, created_at),
    INDEX idx_capture_season_created (season_id, created_at)
);

CREATE TABLE IF NOT EXISTS reapply_runs (
    run_id            BIGINT AUTO_INCREMENT PRIMARY KEY,
    season_id         BIGINT NULL,
    status            VARCHAR(32) NOT NULL,
    total_regions     INT NOT NULL DEFAULT 0,
    success_regions   INT NOT NULL DEFAULT 0,
    failed_regions    INT NOT NULL DEFAULT 0,
    error_summary     TEXT NULL,
    started_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    finished_at       DATETIME NULL,
    CONSTRAINT fk_reapply_season
        FOREIGN KEY (season_id) REFERENCES seasons(season_id)
        ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS region_contract (
    contract_id       BIGINT AUTO_INCREMENT PRIMARY KEY,
    map_version       VARCHAR(64) NOT NULL,
    checksum_sha256   VARCHAR(64) NOT NULL,
    region_count      INT NOT NULL,
    created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_region_contract_version (map_version)
);
