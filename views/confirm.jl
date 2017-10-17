<extend src="layout.jl">
    <block name="body">
        <section class="hero is-bold is-dark">
            <include src="navbar.jl" />
            <div class="hero-body">
                <div class="container has-text-centered is-fluid">
                    <h1 class="title">
                        <i class="fa fa-envelope"></i>
                        &nbsp;Confirm your E-mail Address
                    </h1>
                    <h2 class="subtitle">
                        We only e-mail you when it involves your account security.
                    </h2>
                </div>
            </div>
        </section>
        <section class="section">
            <div class="container">
                <h2 class="subtitle">
                    Enter the confirmation code that was sent to your e-mail.
                    If you don't confirm your account within 24 hours, your
                    account will be wiped from the system.
                </h2>

                <form action="/confirm" method="post">
                    <input name="mode" type="hidden" value="confirm">

                    <div class="field">
                        <div class="control has-icons-left">
                            <input class="input" name="code" placeholder="Confirmation code" type="text">
                            <span class="icon is-small is-left">
                                <i class="fa fa-key"></i>
                            </span>
                        </div>
                    </div>

                    <button class="button is-dark" type="submit" style="width: 100%;">
                        Submit
                    </button>
                </form>

                <hr>

                <h2 class="subtitle">
                    Didn't get the e-mail?
                </h2>

                <form action="/confirm" method="post">
                    <input name="mode" type="hidden" value="reset">
                    <button class="button is-dark" type="submit" style="width: 100%;">
                        <span class="icon">
                            <i class="fa fa-repeat"></i>
                        </span>
                        <span>Send me a new confirmation code.</span>
                    </button>
                </form>
            </div>
        </section>
    </block>
</extend>