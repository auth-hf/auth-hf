<extend src="layout.jl">
    <block name="css">
        <style>
            #overlay {
                background-color: black;
                position: absolute;
                width: 100%;
                height: 100%;
                top: 0;
                left: 0;
                opacity: 0.8;
            }

            .hero {
                position: relative;
                background-size: cover;
            }
        </style>
    </block>

    <block name="body">
        <section class="hero is-fullheight is-bold is-dark">
            <include src="navbar.jl"/>
            <div class="hero-body">
                <div class="container has-text-centered">
                    <h1 class="title">
                        <span class="icon">
                            <i class="fa fa-shield"></i>
                        </span>
                        <span>
                            &nbsp; Auth HF
                        </span>
                    </h1>
                    <h2 class="subtitle">
                        The unofficial OAuth2 provider for HackForums.net.
                    </h2>
                    <a class="button is-dark is-inverted is-outlined" href="#about">
                        Learn More
                    </a>
                    <br><br>
                    <a class="button is-dark is-inverted is-outlined"
                       href="https://github.com/auth-hf/auth-hf/wiki">
                        <span class="icon">
                            <i class="fa fa-book"></i>
                        </span>
                        <span>Documentation</span>
                    </a>
                </div>
            </div>
        </section>
        <section id="about" class="section">
            <div class="container">
                <h1 class="title">
                    <i class="fa fa-plug"></i>
                    &nbsp; It's connected.
                </h1>
                <h2 class="subtitle">
                    Authenticate your users via HackForums.net.
                </h2>
                <p>
                    With Auth HF, it only takes a couple of clicks to register an
                    application. Once registered, you can easily add a
                    "Sign in with HackForums" button to your site.
                    <br><br>
                    Beyond just signing in, Auth HF provides scoped access to
                    the HackForums API, letting you carry out actions for your users.
                </p>
            </div>
        </section>
        <section id="secure" class="section">
            <div class="container">
                <h1 class="title">
                    <i class="fa fa-lock"></i>
                    &nbsp; It's secure.
                </h1>
                <h2 class="subtitle">All data is safe from hackers.</h2>
                <p>
                    No sensitive data, whether it be a password or API key,
                    is ever stored without being hashed or encrypted. All
                    cryptographic operations on Auth HF use three different
                    factors, so even if the database is compromised, your data
                    cannot be stolen.
                    <br><br>
                    No endpoint on this site allows users to readily query the database.
                    <br><br>
                    Applications must use OAuth2, a well-known, secure authentication
                    standard, to access the API on your behalf. <b>No access is ever granted
                    without your express consent.</b> When granting access, you reserve the power
                    to approve <i>access scopes</i>, and thereby explicitly restrict access to
                    areas of your account that you do not want a third party to touch.
                    <br><br>
                    Furthermore, third-party applications will <b>never</b> see
                    your API key. You can rest assured that nobody will ever be able to
                    use Auth HF to hijack your account.
                </p>
            </div>
        </section>
        <section id="free" class="section">
            <div class="container">
                <h1 class="title">
                    <i class="fa fa-gift"></i>
                    &nbsp; It's free.
                </h1>
                <h2 class="subtitle">Auth HF is 100% open-sourced, and costs $0.00 to use.</h2>
                <p>
                    To guarantee transparency, the source code of Auth HF is
                    <a href="https://github.com/auth-hf/auth-hf" target="_blank">publicly viewable</a>.
                    All revenue is sourced from advertisements.
                </p>
            </div>
        </section>
    </block>
</extend>