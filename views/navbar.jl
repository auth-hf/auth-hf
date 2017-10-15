<nav class="navbar is-dark" role="navigation">
    <div class="navbar-brand">
        <a class="navbar-item" href="/">
            <span class="icon">
                <i class="fa fa-shield"></i>
            </span>
            Auth HF
        </a>

        <button class="button navbar-burger">
            <span></span>
            <span></span>
            <span></span>
        </button>
    </div>

    <div class="navbar-menu">
        <div class="navbar-end">
            <a if=user == null href="/login" class="navbar-item">
                <span class="icon">
                    <i class="fa fa-user"></i>
                </span>
                <span>Log In</span>
            </a>
            <a if=user == null href="/signup" class="navbar-item">
                <span class="icon">
                    <i class="fa fa-user"></i>
                </span>
                <span>Sign Up</span>
            </a>

            <div if=user != null class="navbar-item has-dropdown is-boxed is-hoverable">
                <a class="navbar-link">
                    <span class="icon">
                        <i class="fa fa-user-circle"></i>
                    </span>
                    <span>{{ user.email }}</span>
                </a>

                <div class="navbar-dropdown">
                    <a class="navbar-item" href="/applications">
                        <span class="icon">
                            <i class="fa fa-laptop"></i>
                        </span>
                        <span>My Applications</span>
                    </a>
                    <a class="navbar-item" href="/settings">
                        <span class="icon">
                            <i class="fa fa-cogs"></i>
                        </span>
                        <span>Account Settings</span>
                    </a>
                    <a class="navbar-item" href="/signout">
                        <span class="icon">
                            <i class="fa fa-sign-out"></i>
                        </span>
                        <span>Log Out</span>
                    </a>
                </div>
            </div>
        </div>
    </div>
</nav>