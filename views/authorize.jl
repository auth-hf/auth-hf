<extend src="layout.jl">
    <block name="body">
        <section class="hero is-fullheight is-bold is-dark">
            <include src="navbar.jl" />
            <div class="hero-body">
                <div class="container has-text-centered is-fluid">
                    <h1 class="title">Authorize {{ app.name }}?</h1>
                    <h2 class="subtitle">
                        Description:
                        <i>{{ app.description }}</i>
                    </h2>
                    <form action="/oauth2/authorize" method="post">
                        <input name="confirm" type="hidden" value=code.id>

                        <div class="field">
                            <p class="control has-icons-left" style="width: 100%;">
                                <span class="select" style="width: 100%;">
                                    <select name="mode" style="width: 100%;" required>
                                        <option value="" selected>Choose an Action...</option>
                                        <option value="accept">Grant Access</option>
                                        <option value="deny">Deny Access</option>
                                    </select>
                                </span>
                                <span class="icon is-small is-left">
                                    <i class="fa fa-question"></i>
                                </span>
                            </p>
                        </div>

                        <div class="field">
                            <label>
                                Explicitly grant permissions:
                            </label>
                            <select multiple="true" required name="scopes[]" style="width: 100%;">
                                <option for-each=scopes value=item.stub selected=true>
                                    {{ item.description }}
                                </option>
                            </select>
                        </div>

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