<extend src="layout.jl">
    <block name="body">
        <section class="hero is-fullheight is-bold is-dark">
            <include src="navbar.jl" />
            <div class="hero-body">
                <div class="container has-text-centered">
                    <h1 class="title">Authorize {{ app.name }}</h1>
                    <h2 class="subtitle">{{ app.description }}</h2>
                    <form action="/oauth2/authorize" method="post">
                        <div class="select">
                            <select name="mode" required>
                                <option value="">Choose an Action...</option>
                                <option value="accept">Grant Access</option>
                                <option value="deny">Deny Access</option>
                            </select>
                        </div>

                        <input name="confirm" type="hidden" value=code.id>

                        <div class="field is-grouped">
                            <div class="control" style="width: 100%;">
                                <button class="button is-dark is-inverted is-outlined" style="width: 100%;">Submit</button>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </section>
    </block>
</extend>