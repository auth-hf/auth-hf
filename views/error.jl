<extend src="layout.jl">
    <block name="body">
        <section class="hero is-fullheight is-bold is-dark">
            <include src="navbar.jl" />
            <div class="hero-body">
                <div class="container has-text-centered">
                    <h1 class="title">Whoops! Something went wrong.</h1>
                    <h2 class="subtitle">{{ error }}</h2>
                    <a href="/" class="button is-dark is-inverted is-medium is-outlined">
                        <span class="icon">
                            <i class="fa fa-home"></i>
                        </span>
                        <span>Go Home</span>
                    </a>
                </div>
            </div>
        </section>
    </block>
</extend>