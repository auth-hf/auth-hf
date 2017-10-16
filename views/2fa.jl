<extend src="layout.jl">
    <block name="body">
        <section class="hero is-bold is-dark">
            <include src="navbar.jl" />
            <div class="hero-body">
                <div class="container">
                    <h1 class="title">
                        <span class="icon">
                            <i class="fa fa-lock"></i>
                        </span>
                        <span>&nbsp;Two-Factor Authentication</span>
                    </h1>
                    <h2 class="subtitle">Ensuring account security.</h2>
                </div>
            </div>
        </section>
        <section class="section">
            <div class="container">
                <form action="/2fa/" + tfa.id method="post">
                    <div class="field">
                        <label class="label">Enter your 2FA code (sent to your e-mail):</label>
                        <div class="control has-icons-left">
                            <input class="input" name="code" placeholder="2FA Code" type="text">
                            <span class="icon is-small is-left">
                                <i class="fa fa-lock"></i>
                            </span>
                        </div>
                    </div>
                    <button class="button is-dark" type="submit" style="width: 100%">
                        Submit
                    </button>
                </form>
            </div>
        </section>
    </block>
</extend>