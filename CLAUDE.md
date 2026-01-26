# CLAUDE.md - Znuny Project Guide

## Overview

Znuny is an open-source ticket management system, a continuation of OTRS Community Edition. It provides comprehensive ticket handling, customer support, and service management capabilities.

- **Version:** 7.2.x
- **License:** GPL v3
- **Language:** Perl 5.16+
- **Databases:** MySQL 8.0+, MariaDB 10.3+, PostgreSQL 12.0+, Oracle 19c

## Project Structure

```
znuny-mount/
├── Kernel/                     # Core application logic
│   ├── Config.pm               # Main configuration (DO NOT commit)
│   ├── Config/Defaults.pm      # Default settings
│   ├── System/                 # Core business logic (139 modules)
│   │   ├── Ticket.pm           # Ticket management (main module)
│   │   ├── DB.pm               # Database abstraction
│   │   ├── Auth.pm             # Authentication
│   │   └── ...
│   ├── Modules/                # Web interface modules (176 modules)
│   ├── Output/HTML/            # HTML rendering/templates
│   ├── GenericInterface/       # REST API layer
│   ├── Language/               # Translations
│   └── cpan-lib/               # Bundled CPAN dependencies
├── bin/                        # Executables
│   ├── cgi-bin/index.pl        # Agent interface entry
│   ├── cgi-bin/customer.pl     # Customer portal entry
│   ├── znuny.Console.pl        # CLI tool
│   └── znuny.Daemon.pl         # Background daemon
├── Custom/                     # Customizations (survives updates)
├── var/                        # Runtime data
│   ├── httpd/htdocs/skins/     # UI themes/assets
│   ├── article/                # Attachments storage
│   └── log/                    # Application logs
├── scripts/test/               # Unit tests (1,090+ tests)
└── doc/                        # Documentation
```

## Key Commands

```bash
# Check Perl dependencies
perl bin/znuny.CheckModules.pl

# Run console commands
perl bin/znuny.Console.pl List               # List all commands
perl bin/znuny.Console.pl Maint::Cache::Delete  # Clear cache
perl bin/znuny.Console.pl Admin::Config::Update # Update config

# Start/stop daemon
perl bin/znuny.Daemon.pl start
perl bin/znuny.Daemon.pl stop

# Run tests
perl scripts/test/YOURTEST.t
```

## Architecture

### ObjectManager Pattern

All modules are accessed through the central ObjectManager:

```perl
# Get module instance
my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
my $DBObject     = $Kernel::OM->Get('Kernel::System::DB');
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
```

### Module Template

```perl
package Kernel::System::Example;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
    'Kernel::System::DB',
);

sub new {
    my ( $Type, %Param ) = @_;
    my $Self = {};
    bless( $Self, $Type );
    return $Self;
}

sub ExampleMethod {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');

    # Method implementation
    return 1;
}

1;
```

## Coding Conventions

### Naming
- **Classes:** PascalCase (`Kernel::System::Ticket`)
- **Methods:** PascalCase (`TicketCreate`, `TicketGet`)
- **Variables:** camelCase for objects (`$TicketObject`), PascalCase for params (`%Param`)
- **Constants:** UPPERCASE

### Required Headers
```perl
use strict;
use warnings;
use utf8;
```

### Error Handling
```perl
my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

# Log error
$LogObject->Log(
    Priority => 'error',
    Message  => 'Something went wrong: ' . $ErrorMessage,
);

# Return on error
if ( !$Success ) {
    return;
}
```

### Database Operations
```perl
my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

# Use parameterized queries
$DBObject->Do(
    SQL  => 'UPDATE ticket SET title = ? WHERE id = ?',
    Bind => [ \$Title, \$TicketID ],
);

# Fetch results
$DBObject->Prepare(
    SQL   => 'SELECT id, title FROM ticket WHERE queue_id = ?',
    Bind  => [ \$QueueID ],
    Limit => 100,
);

while ( my @Row = $DBObject->FetchrowArray() ) {
    # Process row
}
```

## Key Modules

| Module | Purpose |
|--------|---------|
| `Kernel::System::Ticket` | Ticket CRUD and lifecycle |
| `Kernel::System::DB` | Database abstraction |
| `Kernel::System::Auth` | User authentication |
| `Kernel::System::User` | User management |
| `Kernel::System::Queue` | Queue management |
| `Kernel::System::Cache` | Caching layer |
| `Kernel::System::Log` | Logging |
| `Kernel::Output::HTML::Layout` | HTML rendering |
| `Kernel::GenericInterface::*` | REST API |

## Testing

Tests are in `scripts/test/` using Perl's Test framework:

```perl
# Test file structure
use strict;
use warnings;
use utf8;
use vars (qw($Self));

my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# Assertions
$Self->True( $Condition, 'Test description' );
$Self->Is( $Got, $Expected, 'Values match' );
$Self->False( $Condition, 'Should be false' );
```

## Customization

Place custom code in `Custom/` directory - it survives updates:
- `Custom/Kernel/System/` - Custom system modules
- `Custom/Kernel/Modules/` - Custom web modules

## Web Interfaces

- **Agent:** `http://host/otrs/index.pl` - Staff interface
- **Customer:** `http://host/otrs/customer.pl` - Customer portal
- **API:** `http://host/otrs/nph-genericinterface.pl` - REST/SOAP

## Configuration

Main config in `Kernel/Config.pm` (not tracked in git):

```perl
$Self->{DatabaseHost} = 'localhost';
$Self->{Database}     = 'znuny';
$Self->{DatabaseUser} = 'znuny';
$Self->{DatabasePw}   = 'password';
```

System settings via SysConfig (Admin panel) or console:
```bash
perl bin/znuny.Console.pl Admin::Config::Update --setting-name SettingName --value "NewValue"
```

## Documentation

- Official docs: https://doc.znuny.org/
- Developer docs: https://doc.znuny.org/znuny/developer/
- Community: https://community.znuny.org/
